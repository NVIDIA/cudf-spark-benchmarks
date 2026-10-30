WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' 
    AND o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerSummary AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(c.c_acctbal) AS total_acctbal
    FROM customer c
    GROUP BY c.c_nationkey
),
SupplierDetails AS (
    SELECT 
        s.s_nationkey,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    GROUP BY s.s_nationkey
),
MixedResults AS (
    SELECT 
        r.r_name AS region_name,
        COALESCE(cs.total_customers, 0) AS total_customers,
        COALESCE(cs.total_acctbal, 0) AS total_acctbal,
        COALESCE(sd.avg_acctbal, 0) AS avg_supplier_acctbal,
        SUM(os.total_revenue) AS total_revenue
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN CustomerSummary cs ON n.n_nationkey = cs.c_nationkey
    LEFT JOIN SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
    LEFT JOIN OrderSummary os ON n.n_nationkey = os.o_orderkey
    GROUP BY r.r_name, cs.total_customers, cs.total_acctbal, sd.avg_acctbal
)
SELECT 
    m.region_name,
    m.total_customers,
    m.total_acctbal,
    m.avg_supplier_acctbal,
    m.total_revenue,
    CASE 
        WHEN m.total_revenue > 100000 THEN 'High Revenue' 
        WHEN m.total_revenue BETWEEN 50000 AND 100000 THEN 'Medium Revenue' 
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM MixedResults m
ORDER BY m.total_revenue DESC, m.region_name;