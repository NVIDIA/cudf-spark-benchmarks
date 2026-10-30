
WITH SuppliersWithParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey, 
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_availqty DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 100.00
),

TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000.00
)

SELECT 
    t.s_suppkey,
    t.s_name,
    p.p_partkey,
    p.p_name,
    COALESCE(sp.avg_discount, 0) AS avg_discount,
    CASE 
        WHEN t.total_supply_cost IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status
FROM 
    TopSuppliers t
LEFT JOIN 
    SuppliersWithParts p ON t.s_suppkey = p.s_suppkey AND p.rn = 1
LEFT JOIN 
    (SELECT 
        l.l_suppkey,
        AVG(l.l_discount) AS avg_discount 
     FROM 
        lineitem l 
     GROUP BY 
        l.l_suppkey) sp ON t.s_suppkey = sp.l_suppkey
WHERE 
    (t.s_suppkey % 2 = 0 OR t.s_name LIKE 'A%')
ORDER BY 
    t.total_supply_cost DESC
LIMIT 100;
