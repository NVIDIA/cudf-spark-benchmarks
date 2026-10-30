WITH  customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
),
supply_availability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        AVG(l.l_discount) AS avg_discount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    co.c_name,
    co.o_orderkey,
    co.o_orderdate,
    COALESCE(ls.net_revenue, 0) AS net_revenue,
    COALESCE(av.total_available, 0) AS total_available,
    av.total_supply_cost,
    CASE 
        WHEN ls.net_revenue > 10000 THEN 'High Value'
        WHEN ls.net_revenue BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    customer_orders co
LEFT JOIN 
    lineitem_summary ls ON co.o_orderkey = ls.l_orderkey
LEFT JOIN 
    supply_availability av ON ls.l_orderkey = av.ps_partkey
WHERE 
    co.order_rank <= 5
ORDER BY 
    co.o_orderdate DESC, co.c_name;