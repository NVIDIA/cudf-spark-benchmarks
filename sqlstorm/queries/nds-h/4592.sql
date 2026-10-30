
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 

OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_discount) AS total_discount,
        COUNT(DISTINCT l.l_orderkey) AS line_count,
        AVG(l.l_extendedprice) AS avg_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_discount) DESC) AS discount_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)

SELECT 
    r.r_name,
    n.n_name,
    s.s_name,
    ss.total_available_quantity,
    os.total_discount,
    os.line_count,
    os.avg_price
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    OrderSummary os ON os.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
WHERE 
    ss.total_available_quantity IS NOT NULL 
    AND (os.total_discount > 0 OR os.line_count > 0)
    AND r.r_name LIKE '%East%'
ORDER BY 
    ss.total_supply_cost DESC, os.avg_price ASC;
