WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate > DATE '1996-01-01'
),
product_suppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
supply_info AS (
    SELECT 
        s.s_name,
        n.n_name AS supplier_nation,
        s.s_acctbal,
        p.p_partkey,
        p.p_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    so.supplier_nation,
    COUNT(DISTINCT so.s_name) AS number_of_suppliers,
    SUM(CASE WHEN so.s_acctbal IS NOT NULL THEN so.s_acctbal ELSE 0 END) AS total_acct_balance,
    MAX(po.total_cost) AS max_product_cost,
    AVG(o.o_totalprice) AS avg_order_total
FROM 
    supply_info so
LEFT JOIN 
    product_suppliers po ON so.p_partkey = po.ps_partkey
LEFT JOIN 
    ranked_orders o ON o.o_orderkey = so.p_partkey  
WHERE 
    so.supplier_nation IS NOT NULL
GROUP BY 
    so.supplier_nation
HAVING 
    COUNT(DISTINCT so.s_name) > 5
ORDER BY 
    total_acct_balance DESC;