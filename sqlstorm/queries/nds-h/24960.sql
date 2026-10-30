WITH RankedLines AS (
    SELECT 
        l.*,
        RANK() OVER (PARTITION BY l_orderkey ORDER BY l_extendedprice DESC) AS price_rank
    FROM 
        lineitem l
    WHERE 
        l_shipdate >= cast('1998-10-01' as date) - INTERVAL '365 days'
        AND l_returnflag = 'N'
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 0
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice,
        COUNT(DISTINCT l.l_orderkey) AS order_line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey, o.o_totalprice
    HAVING 
        o.o_totalprice > 1000
),
NationCustomers AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = n.n_nationkey)
    GROUP BY 
        n.n_name
),
JoinResults AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        (SELECT COUNT(*) FROM FilteredSuppliers fs WHERE fs.total_cost > 0) AS supplier_count,
        (SELECT MAX(customer_count) FROM NationCustomers) AS max_nation_customers
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        r.r_name
)
SELECT 
    jr.r_name,
    jr.total_orders,
    jr.total_revenue,
    jr.supplier_count,
    jr.max_nation_customers,
    CASE 
        WHEN jr.total_revenue IS NULL THEN 'No Revenue'
        WHEN jr.total_revenue > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS revenue_status
FROM 
    JoinResults jr
WHERE 
    jr.total_orders >= (SELECT AVG(total_orders) FROM JoinResults)
ORDER BY 
    jr.total_revenue DESC
LIMIT 10;