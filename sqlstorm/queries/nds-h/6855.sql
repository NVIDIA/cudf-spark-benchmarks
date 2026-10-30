WITH region_orders AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        r.r_name
),
part_supplier AS (
    SELECT
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
line_item_analysis AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity_sold,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
)
SELECT 
    ro.region_name,
    psi.total_available_qty,
    psi.avg_supply_cost,
    lia.total_quantity_sold,
    lia.total_sales,
    ro.total_orders,
    ro.total_revenue
FROM 
    region_orders ro
JOIN 
    part_supplier psi ON psi.p_partkey IN (SELECT l.l_partkey FROM lineitem l)
JOIN 
    line_item_analysis lia ON lia.l_partkey = psi.p_partkey
ORDER BY 
    ro.total_revenue DESC, 
    ro.region_name ASC
LIMIT 10;
