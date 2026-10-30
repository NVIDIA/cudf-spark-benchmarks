WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),

supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        AVG(ps.ps_supplycost) < 100.00
),

customer_order_counts AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),

nation_supplier AS (
    SELECT 
        n.n_name,
        COUNT(s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)

SELECT 
    n.n_name,
    ns.supplier_count,
    ns.total_account_balance,
    SUM(COALESCE(c.order_count, 0)) AS total_orders,
    SUM(CASE 
            WHEN r.rn <= 10 THEN r.o_totalprice 
            ELSE 0 
        END) AS top_orders_total
FROM 
    nation_supplier ns
JOIN 
    nation n ON ns.n_name = n.n_name
LEFT JOIN 
    customer_order_counts c ON ns.supplier_count > 0
LEFT JOIN 
    ranked_orders r ON r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
WHERE 
    ns.total_account_balance IS NOT NULL
GROUP BY 
    n.n_name, ns.supplier_count, ns.total_account_balance
ORDER BY 
    total_orders DESC, n.n_name;