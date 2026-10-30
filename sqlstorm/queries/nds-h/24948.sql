
WITH RecursiveOrderStats AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_custkey
    FROM
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate, o.o_custkey
),
SupplierStats AS (
    SELECT
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM
        partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        ps.ps_partkey, s.s_nationkey
),
NationRank AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        RANK() OVER (ORDER BY SUM(ss.total_supplycost) DESC) AS nation_rank
    FROM
        nation n
    JOIN SupplierStats ss ON n.n_nationkey = ss.s_nationkey
    GROUP BY
        n.n_nationkey, n.n_name
),
CustomerNR AS (
    SELECT 
        c.c_custkey,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM 
        customer c
)
SELECT 
    cs.c_custkey,
    COUNT(DISTINCT ro.o_orderkey) AS distinct_orders,
    COALESCE(SUM(ro.total_revenue), 0) AS total_revenue,
    CASE 
        WHEN nr.nation_rank IS NOT NULL THEN 'Top Nation'
        ELSE 'Other'
    END AS nation_category
FROM 
    CustomerNR cs
LEFT JOIN RecursiveOrderStats ro ON cs.c_custkey = ro.o_custkey
LEFT JOIN NationRank nr ON cs.c_nationkey = nr.n_nationkey
WHERE 
    cs.cust_rank <= 10
GROUP BY 
    cs.c_custkey, nr.nation_rank
HAVING 
    SUM(COALESCE(ro.total_revenue, 0)) > 10000
ORDER BY 
    total_revenue DESC, cs.c_custkey;
