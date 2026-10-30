
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM orders o
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) 
        FROM orders o2 
        WHERE o2.o_orderstatus = o.o_orderstatus
    )
),
NationalSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice
    FROM part p
    WHERE p.p_retailprice IS NOT NULL AND p.p_retailprice < (
        SELECT MAX(p2.p_retailprice) FROM part p2
    ) / 2
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_returnflag,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS LineRank
    FROM lineitem l
    WHERE l.l_returnflag = 'R'
),
JoinResults AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM FilteredParts p
    JOIN OrderLineItems l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    r.nation_name,
    COALESCE(j.revenue, 0) AS total_revenue,
    CASE WHEN j.revenue IS NULL THEN 'NO REVENUE' ELSE 'HAS REVENUE' END AS revenue_status
FROM RankedOrders o
LEFT JOIN NationalSuppliers r ON o.o_orderkey % r.s_suppkey = 0
LEFT JOIN JoinResults j ON o.o_orderkey = j.p_partkey
WHERE o.OrderRank <= 5
ORDER BY o.o_orderdate DESC, o.o_totalprice DESC;
