WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_retailprice,
    pd.supplier_count,
    cs.c_name,
    cs.total_spent,
    rs.s_name AS top_supplier,
    rs.total_supply_cost
FROM 
    PartDetails pd
LEFT JOIN 
    CustomerOrders cs ON pd.supplier_count > 2 
JOIN 
    RankedSuppliers rs ON rs.rnk = 1
WHERE 
    pd.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)  
  AND 
    (pd.p_name LIKE '%premium%' OR pd.p_name IS NULL)  
ORDER BY 
    pd.p_retailprice DESC, cs.total_spent ASC
LIMIT 10;