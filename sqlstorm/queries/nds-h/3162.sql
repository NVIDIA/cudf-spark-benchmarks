
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
supplier_part_info AS (
    SELECT 
        s.s_name,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, p.p_name
),
growth_rate AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        CASE 
            WHEN COUNT(DISTINCT c.c_custkey) > 0 THEN 
                COUNT(DISTINCT o.o_orderkey) * 1.0 / COUNT(DISTINCT c.c_custkey) 
            ELSE 0 
        END AS order_per_customer
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name,
    si.s_name,
    si.p_name,
    si.total_available,
    si.avg_supply_cost,
    go.total_customers,
    go.total_orders,
    go.order_per_customer,
    ro.o_orderkey,
    ro.total_sales
FROM 
    region r
LEFT JOIN 
    supplier_part_info si ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = 'Germany' LIMIT 1)
LEFT JOIN 
    growth_rate go ON go.n_name = r.r_name
LEFT JOIN 
    ranked_orders ro ON ro.o_orderkey = (SELECT o_orderkey FROM ranked_orders WHERE sales_rank = 1 LIMIT 1)
ORDER BY 
    r.r_name, si.s_name, ro.total_sales DESC NULLS LAST;
