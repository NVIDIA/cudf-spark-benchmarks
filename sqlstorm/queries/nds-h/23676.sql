WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ps.ps_availqty,
        p.p_mfgr
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
        AND ps.ps_availqty > 0
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
NullCheck AS (
    SELECT 
        l.l_orderkey, 
        l.l_discount, 
        CASE 
            WHEN l.l_shipdate IS NULL THEN 'No Shipment'
            ELSE 'Shipped'
        END AS shipment_status
    FROM 
        lineitem l
    WHERE 
        l.l_discount IS NOT NULL
),
FinalResults AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        os.order_count,
        os.total_spent,
        rs.s_name AS top_supplier,
        hp.p_name,
        hp.p_retailprice
    FROM 
        customer c 
    LEFT JOIN 
        OrderSummary os ON c.c_custkey = os.o_custkey
    LEFT JOIN 
        RankedSuppliers rs ON c.c_nationkey = rs.s_suppkey AND rs.rn = 1
    LEFT JOIN 
        HighValueParts hp ON hp.p_partkey = (SELECT MAX(hp2.p_partkey) FROM HighValueParts hp2)
    WHERE 
        os.order_count IS NOT NULL 
        OR (hp.p_retailprice IS NOT NULL AND hp.p_retailprice > 100.00)
)
SELECT 
    f.c_custkey,
    f.c_name,
    f.order_count,
    f.total_spent,
    COALESCE(f.top_supplier, 'N/A') AS top_supplier,
    COALESCE(f.p_name, 'No High Value Parts') AS high_value_part,
    COALESCE(f.p_retailprice, 0) AS retail_price
FROM 
    FinalResults f
WHERE 
    NOT EXISTS (SELECT 1 FROM NullCheck n WHERE n.l_orderkey = f.c_custkey AND n.l_discount > 0.10)
ORDER BY 
    f.total_spent DESC, 
    f.c_name;
