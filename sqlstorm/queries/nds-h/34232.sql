
WITH  order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000.00
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 100
)
SELECT 
    ns.n_name,
    COALESCE(os.total_revenue, 0) AS total_revenue,
    COALESCE(tc.total_spent, 0) AS customer_spending,
    COALESCE(ss.total_cost, 0) AS supplier_cost
FROM 
    nation ns
LEFT JOIN 
    order_summary os ON ns.n_nationkey = os.o_orderkey
LEFT JOIN 
    top_customers tc ON ns.n_nationkey = tc.c_custkey
LEFT JOIN 
    supplier_summary ss ON ns.n_nationkey = ss.s_suppkey
WHERE 
    ns.n_nationkey IN (SELECT n_nationkey FROM nation WHERE n_comment IS NOT NULL)
ORDER BY 
    total_revenue DESC, customer_spending DESC, supplier_cost DESC
LIMIT 10;
