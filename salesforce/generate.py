import os, shutil
ROOT = os.path.dirname(os.path.abspath(__file__))
API = "60.0"
HDR = '<?xml version="1.0" encoding="UTF-8"?>\n'

def picklist(name, label, values, desc):
    vals = "".join(f"""
                <value>
                    <fullName>{v}</fullName>
                    <default>false</default>
                    <label>{v}</label>
                </value>""" for v in values)
    return f"""
    <fields>
        <fullName>{name}</fullName>
        <description>{desc}</description>
        <externalId>false</externalId>
        <label>{label}</label>
        <required>false</required>
        <trackHistory>false</trackHistory>
        <type>Picklist</type>
        <valueSet>
            <restricted>true</restricted>
            <valueSetDefinition>
                <sorted>false</sorted>{vals}
            </valueSetDefinition>
        </valueSet>
    </fields>"""

def currency(name, label, desc):
    return f"""
    <fields>
        <fullName>{name}</fullName>
        <description>{desc}</description>
        <externalId>false</externalId>
        <label>{label}</label>
        <precision>16</precision>
        <required>false</required>
        <scale>0</scale>
        <trackHistory>false</trackHistory>
        <type>Currency</type>
    </fields>"""

CORE = [
    ("Inner_Circle_Tier__c", picklist("Inner_Circle_Tier__c", "Inner Circle Tier",
        ["Top 12", "Rising 25", "Dream 50", "Steady Support", "Lapsed Lead"],
        "Donor portfolio tier, assigned manually after reviewing Suggested Tier."), True),
    ("Estimated_Net_Worth__c", currency("Estimated_Net_Worth__c", "Estimated Net Worth",
        "From wealth screening or prospect research."), True),
    ("Largest_Known_Outside_Gift__c", currency("Largest_Known_Outside_Gift__c", "Largest Known Outside Gift",
        "Largest known gift this person made to another organization."), True),
    ("Mission_Alignment__c", picklist("Mission_Alignment__c", "Mission Alignment",
        ["Strong", "Moderate", "Unknown"], "How strongly the donor connects with the mission."), True),
    ("Relationship_Depth__c", picklist("Relationship_Depth__c", "Relationship Depth",
        ["Personal", "Acquainted", "None"], "How well the Rabbi knows the donor personally."), True),
    ("Alignment_Notes__c", """
    <fields>
        <fullName>Alignment_Notes__c</fullName>
        <description>Values, story and connection to the mission.</description>
        <externalId>false</externalId>
        <label>Alignment Notes</label>
        <length>32768</length>
        <trackHistory>false</trackHistory>
        <type>LongTextArea</type>
        <visibleLines>5</visibleLines>
    </fields>""", True),
    ("Next_Step__c", """
    <fields>
        <fullName>Next_Step__c</fullName>
        <description>The next concrete action with this donor.</description>
        <externalId>false</externalId>
        <label>Next Step</label>
        <length>255</length>
        <required>false</required>
        <trackHistory>false</trackHistory>
        <type>Text</type>
        <unique>false</unique>
    </fields>""", True),
    ("Next_Step_Date__c", """
    <fields>
        <fullName>Next_Step_Date__c</fullName>
        <description>When the next step is due.</description>
        <externalId>false</externalId>
        <label>Next Step Date</label>
        <required>false</required>
        <trackHistory>false</trackHistory>
        <type>Date</type>
    </fields>""", True),
]

SUGGESTED = """IF( AND( MAX(npo02__LargestAmount__c, Largest_Known_Outside_Gift__c) &gt;= 100000,
         Estimated_Net_Worth__c &gt;= 5000000 ), &quot;Top 12 candidate&quot;,
IF( AND( MAX(npo02__LargestAmount__c, Largest_Known_Outside_Gift__c) &gt;= 10000,
         Estimated_Net_Worth__c &gt;= 1000000 ), &quot;Rising 25 candidate&quot;,
IF( npo02__NumberOfClosedOpps__c = 0, &quot;Prospect (Dream 50?)&quot;,
IF( npo02__LastCloseDate__c &lt; TODAY() - 548, &quot;Lapsed&quot;,
    &quot;Steady Support&quot; ))))"""

OVERDUE = """AND(
  NOT(ISBLANK(TEXT(Inner_Circle_Tier__c))),
  OR(
    AND(ISBLANK(LastActivityDate), NOT(ISPICKVAL(Inner_Circle_Tier__c, &quot;Steady Support&quot;))),
    CASE( TEXT(Inner_Circle_Tier__c),
      &quot;Top 12&quot;,      TODAY() - LastActivityDate &gt; 7,
      &quot;Rising 25&quot;,   TODAY() - LastActivityDate &gt; 15,
      &quot;Dream 50&quot;,    TODAY() - LastActivityDate &gt; 30,
      &quot;Lapsed Lead&quot;, TODAY() - LastActivityDate &gt; 90,
      FALSE )
  )
)"""

FORMULAS = [
    ("Suggested_Tier__c", f"""
    <fields>
        <fullName>Suggested_Tier__c</fullName>
        <description>Tier suggested by giving history and net worth. Requires NPSP rollup fields.</description>
        <externalId>false</externalId>
        <formula>{SUGGESTED}</formula>
        <formulaTreatBlanksAs>BlankAsZero</formulaTreatBlanksAs>
        <label>Suggested Tier</label>
        <required>false</required>
        <trackHistory>false</trackHistory>
        <type>Text</type>
        <unique>false</unique>
    </fields>""", False),
    ("Touch_Overdue__c", f"""
    <fields>
        <fullName>Touch_Overdue__c</fullName>
        <defaultValue>false</defaultValue>
        <description>True when the donor is past the touch cadence for their tier (Top 12: 7 days, Rising 25: 15, Dream 50: 30, Lapsed Lead: 90).</description>
        <externalId>false</externalId>
        <formula>{OVERDUE}</formula>
        <label>Touch Overdue</label>
        <trackHistory>false</trackHistory>
        <type>Checkbox</type>
    </fields>""", False),
]

def build(pkg, fields):
    d = os.path.join(ROOT, pkg)
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(f"{d}/objects"); os.makedirs(f"{d}/permissionsets")
    with open(f"{d}/objects/Contact.object", "w") as f:
        f.write(HDR + '<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">'
                + "".join(x for _, x, _ in fields) + "\n</CustomObject>\n")
    perms = "".join(f"""
    <fieldPermissions>
        <editable>{str(ed).lower()}</editable>
        <field>Contact.{n}</field>
        <readable>true</readable>
    </fieldPermissions>""" for n, _, ed in fields)
    with open(f"{d}/permissionsets/Inner_Circle_Fundraising.permissionset", "w") as f:
        f.write(HDR + f"""<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Access to the Inner Circle donor segmentation fields on Contact.</description>{perms}
    <hasActivationRequired>false</hasActivationRequired>
    <label>Inner Circle Fundraising</label>
</PermissionSet>
""")
    members = "".join(f"\n        <members>Contact.{n}</members>" for n, _, _ in fields)
    with open(f"{d}/package.xml", "w") as f:
        f.write(HDR + f"""<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>{members}
        <name>CustomField</name>
    </types>
    <types>
        <members>Inner_Circle_Fundraising</members>
        <name>PermissionSet</name>
    </types>
    <version>{API}</version>
</Package>
""")

build("1-inner-circle-fields", CORE)
build("2-inner-circle-formulas-npsp", CORE + FORMULAS)
