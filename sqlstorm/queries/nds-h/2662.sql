WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
nation_supplier AS (
    SELECT 
        n.n_name,
        s.s_suppkey,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name, s.s_suppkey, s.s_acctbal
),
high_value_orders AS (
    SELECT 
        r.o_orderkey,
        r.o_totalprice,
        n.n_name,
        ns.total_cost
    FROM 
        ranked_orders r
    JOIN 
        lineitem l ON r.o_orderkey = l.l_orderkey
    LEFT JOIN 
        nation_supplier ns ON l.l_suppkey = ns.s_suppkey
    JOIN 
        nation n ON ns.n_name = n.n_name
    WHERE 
        r.price_rank <= 10
    AND 
        ns.total_cost IS NOT NULL
),
final_summary AS (
    SELECT 
        hvo.n_name,
        COUNT(*) AS order_count,
        SUM(hvo.o_totalprice) AS total_revenue,
        AVG(ns.s_acctbal) AS avg_supplier_balance
    FROM 
        high_value_orders hvo
    JOIN 
        nation_supplier ns ON hvo.n_name = ns.n_name
    GROUP BY 
        hvo.n_name
)
SELECT 
    fs.n_name, 
    fs.order_count, 
    fs.total_revenue, 
    COALESCE(fs.avg_supplier_balance, 0) AS avg_supplier_balance
FROM 
    final_summary fs
ORDER BY 
    fs.total_revenue DESC;