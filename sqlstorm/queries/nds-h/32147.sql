
WITH  cust_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
sup_part AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
),
max_region AS (
    SELECT 
        n.n_regionkey,
        MAX(s.s_acctbal) AS max_acctbal
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_regionkey
),
total_sales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l.l_partkey
),
final_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ts.total_revenue, 0) AS total_revenue,
        COALESCE(sp.total_cost, 0) AS total_cost,
        mr.max_acctbal
    FROM 
        part p
    LEFT JOIN 
        total_sales ts ON p.p_partkey = ts.l_partkey
    LEFT JOIN 
        sup_part sp ON p.p_partkey = sp.ps_partkey
    LEFT JOIN 
        max_region mr ON sp.s_suppkey = mr.n_regionkey
)
SELECT 
    fs.p_partkey,
    fs.p_name,
    fs.total_revenue,
    fs.total_cost,
    CASE 
        WHEN fs.total_revenue > fs.total_cost THEN 'Profitable'
        WHEN fs.total_revenue < fs.total_cost THEN 'Not Profitable'
        ELSE 'Break Even'
    END AS profitability,
    COUNT(co.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT CAST(co.o_orderkey AS STRING), ', ') AS order_keys
FROM 
    final_summary fs
LEFT JOIN 
    cust_orders co ON fs.p_partkey = co.o_orderkey
GROUP BY 
    fs.p_partkey, fs.p_name, fs.total_revenue, fs.total_cost, fs.max_acctbal
ORDER BY 
    fs.total_revenue DESC
LIMIT 100;
