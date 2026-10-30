WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
),
HighValueOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_line_value,
        CASE 
            WHEN os.total_line_value > 10000 THEN 'High'
            ELSE 'Normal'
        END AS order_value_category
    FROM 
        OrderStats os
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    ss.total_avail_qty,
    ss.avg_supply_cost,
    hvo.total_line_value,
    hvo.order_value_category
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    HighValueOrders hvo ON s.s_suppkey = hvo.o_orderkey
WHERE 
    ss.total_avail_qty IS NOT NULL
    OR hvo.total_line_value IS NOT NULL
ORDER BY 
    region_name,
    nation_name,
    supplier_name;
