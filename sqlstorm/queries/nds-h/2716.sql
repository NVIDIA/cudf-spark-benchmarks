WITH ranked_nations AS (
    SELECT 
        n_nationkey,
        n_name,
        ROW_NUMBER() OVER (PARTITION BY n_regionkey ORDER BY n_name) AS rank
    FROM 
        nation
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        AVG(l.l_tax) AS avg_tax,
        MAX(l.l_shipdate) AS last_shipdate
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name,
    p.p_name,
    SD.s_name AS supplier_name,
    CO.c_name AS customer_name,
    CO.order_count,
    CO.total_spent,
    LS.revenue,
    LS.avg_tax,
    LS.last_shipdate
FROM 
    region r
JOIN 
    ranked_nations rn ON r.r_regionkey = rn.n_nationkey
JOIN 
    nation n ON rn.n_nationkey = n.n_nationkey
JOIN 
    supplier_details SD ON n.n_nationkey = SD.s_nationkey
JOIN 
    partsupp ps ON SD.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    customer_orders CO ON CO.c_custkey = r.r_regionkey
JOIN 
    lineitem_summary LS ON LS.l_orderkey = CO.c_custkey
WHERE 
    p.p_retailprice > 100.00 
    AND CO.total_spent IS NOT NULL
    AND LS.revenue > (SELECT AVG(revenue) FROM lineitem_summary)
ORDER BY 
    r.r_name, p.p_name, CO.total_spent DESC;
