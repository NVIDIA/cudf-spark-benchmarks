WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderstatus
), CustomerPurchases AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COALESCE(SUM(r.total_revenue), 0) AS total_spent
    FROM 
        customer c 
    LEFT JOIN 
        RankedOrders r ON c.c_custkey = r.o_custkey
    GROUP BY 
        c.c_custkey, 
        c.c_name
), HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal
    FROM 
        customer c 
    JOIN 
        CustomerPurchases cp ON c.c_custkey = cp.c_custkey
    WHERE 
        cp.total_spent > 10000 AND 
        c.c_acctbal IS NOT NULL
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_count,
    AVG(hvc.c_acctbal) AS average_acct_balance
FROM 
    HighValueCustomers hvc
JOIN 
    supplier s ON hvc.c_custkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    n.n_name, 
    r.r_name
HAVING 
    COUNT(DISTINCT hvc.c_custkey) > 5
ORDER BY 
    average_acct_balance DESC
LIMIT 10;