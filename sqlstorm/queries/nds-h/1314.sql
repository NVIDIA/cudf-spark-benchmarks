WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    co.c_name,
    SUM(lic.l_extendedprice * (1 - lic.l_discount)) AS revenue,
    COUNT(DISTINCT CASE WHEN lic.l_returnflag = 'R' THEN o.o_orderkey END) AS returned_orders,
    COUNT(DISTINCT lic.l_orderkey) AS total_line_items,
    MAX(COALESCE(ps.p_name, 'No Part Information')) AS part_name,
    MAX(CASE WHEN ps.rn = 1 THEN ps.ps_availqty END) AS min_avail_qty
FROM 
    CustomerOrderSummary co
JOIN 
    orders o ON co.c_custkey = o.o_custkey
JOIN 
    lineitem lic ON o.o_orderkey = lic.l_orderkey
LEFT JOIN 
    PartSupplierInfo ps ON lic.l_partkey = ps.p_partkey
WHERE 
    o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND co.total_spent > 500
GROUP BY 
    co.c_name
HAVING 
    SUM(lic.l_extendedprice * (1 - lic.l_discount)) > 1000
ORDER BY 
    revenue DESC, co.c_name ASC;