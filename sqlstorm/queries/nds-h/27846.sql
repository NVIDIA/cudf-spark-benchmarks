
WITH PartDetail AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_mfgr, p.p_type, p.p_container, p.p_retailprice, p.p_comment
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date,
        c.c_mktsegment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_brand,
    cod.c_custkey,
    cod.c_name,
    cod.total_spent,
    pd.supplier_count,
    pd.total_available_quantity,
    pd.total_supply_cost
FROM 
    PartDetail pd
JOIN 
    CustomerOrderDetails cod ON pd.p_brand = LEFT(cod.c_name, CHAR_LENGTH(cod.c_name) / 2)
WHERE 
    pd.p_retailprice > (SELECT AVG(p.p_retailprice) FROM part p)
ORDER BY 
    cod.total_spent DESC, pd.p_retailprice ASC
LIMIT 50;
