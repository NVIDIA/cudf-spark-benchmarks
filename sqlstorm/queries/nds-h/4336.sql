
WITH supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
lineitem_details AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_rank
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate <= DATE '1998-10-01' - INTERVAL '30 days'
),
avg_discount AS (
    SELECT 
        AVG(l.l_discount) AS avg_line_discount
    FROM 
        lineitem_details l
    WHERE 
        l.line_rank <= 5
)
SELECT 
    s_info.s_name,
    s_info.nation_name,
    s_info.total_supply_cost,
    c_summary.c_name,
    c_summary.order_count,
    c_summary.total_spent,
    (SELECT avg_discount.avg_line_discount FROM avg_discount) AS average_discount
FROM 
    supplier_info s_info
JOIN 
    customer_order_summary c_summary ON s_info.s_suppkey = c_summary.c_custkey
WHERE 
    s_info.total_supply_cost > (SELECT AVG(total_supply_cost) FROM supplier_info)
    AND c_summary.total_spent IS NOT NULL
ORDER BY 
    s_info.total_supply_cost DESC, c_summary.total_spent DESC
LIMIT 10;
