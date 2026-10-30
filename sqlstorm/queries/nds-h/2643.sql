WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
BestCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
LeftJoinResults AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(sum(ps.ps_availqty), 0) AS total_available,
        (SELECT COUNT(*) FROM partsupp) AS total_partsupp
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT bc.c_custkey) AS total_best_customers,
    AVG(bc.customer_revenue) AS avg_revenue,
    lr.p_name,
    lr.total_available,
    CASE 
        WHEN lr.total_available > 0 THEN 'Available'
        ELSE 'Out of Stock'
    END AS stock_status
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    BestCustomers bc ON s.s_suppkey = bc.c_custkey
JOIN 
    LeftJoinResults lr ON s.s_suppkey = lr.p_partkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name, lr.p_name, lr.total_available
HAVING 
    COUNT(DISTINCT bc.c_custkey) > 5
ORDER BY 
    avg_revenue DESC, stock_status ASC;