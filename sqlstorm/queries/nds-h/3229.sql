WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),

CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' OR o.o_orderdate IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
LineitemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    ss.total_avail_qty,
    ss.avg_supply_cost,
    ld.total_line_value,
    ld.unique_parts
FROM 
    CustomerOrderStats cs
FULL OUTER JOIN 
    SupplierStats ss ON cs.c_custkey = ss.s_suppkey
LEFT JOIN 
    LineitemDetails ld ON cs.total_orders = ld.l_orderkey
WHERE 
    (cs.total_spent > 10000 OR ss.total_avail_qty IS NULL)
ORDER BY 
    cs.total_orders DESC, ss.avg_supply_cost ASC;