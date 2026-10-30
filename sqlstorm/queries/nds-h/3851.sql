WITH top_part_suppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
order_line_stats AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_linenumber) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
),
regional_summary AS (
    SELECT 
        n.n_regionkey,
        SUM(o.o_totalprice) AS total_orders,
        AVG(c.c_acctbal) AS avg_customer_balance
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_regionkey
)
SELECT 
    r.r_name,
    r.r_comment,
    COALESCE(SUM(tpsc.total_supply_cost), 0) AS total_part_cost,
    COALESCE(SUM(cus.order_count), 0) AS total_orders_by_customers,
    COALESCE(SUM(ols.total_value), 0) AS total_line_item_value,
    SUM(rs.total_orders) AS total_orders_in_region,
    AVG(rs.avg_customer_balance) AS avg_balance_in_region
FROM 
    region r
LEFT JOIN 
    regional_summary rs ON r.r_regionkey = rs.n_regionkey
LEFT JOIN 
    top_part_suppliers tpsc ON tpsc.ps_partkey = (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_retailprice > 50 
        ORDER BY p.p_partkey 
        LIMIT 1
    )
LEFT JOIN 
    customer_orders cus ON cus.c_custkey = (
        SELECT MIN(c.c_custkey) 
        FROM customer c 
        WHERE c.c_mktsegment = 'AUTOMOBILE'
    )
LEFT JOIN 
    order_line_stats ols ON ols.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'F'
    )
GROUP BY 
    r.r_name, r.r_comment
ORDER BY 
    r.r_name;
