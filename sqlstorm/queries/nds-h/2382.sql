WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        MAX(l.l_shipdate) AS latest_ship_date,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
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
    ss.num_parts,
    ss.total_avail_qty,
    ss.avg_supply_cost,
    oi.total_price,
    oi.latest_ship_date
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
JOIN 
    OrderInfo oi ON oi.o_custkey = s.s_suppkey
WHERE 
    ss.num_parts IS NOT NULL 
    AND oi.order_rank = 1 
    AND ss.total_avail_qty > 100
ORDER BY 
    r.r_name, n.n_name, oi.latest_ship_date DESC;
