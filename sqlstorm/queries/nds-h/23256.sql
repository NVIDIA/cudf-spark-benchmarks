WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as rank_total
    FROM
        orders o
    WHERE
        o.o_orderdate BETWEEN DATE '1994-01-01' AND DATE '1994-12-31'
        AND o.o_totalprice IS NOT NULL
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank_acctbal
    FROM
        supplier s
    WHERE
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2) 
    ORDER BY s.s_acctbal DESC
),
TopLineItems AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_for_order,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM
        lineitem l
    GROUP BY
        l.l_orderkey
    HAVING
        COUNT(*) > 5
)
SELECT
    r.o_orderkey,
    r.o_totalprice,
    CASE 
        WHEN r.rank_total <= 10 THEN 'Top 10 Orders'
        ELSE 'Other Orders'
    END AS Order_Category,
    s.s_name,
    s.s_acctbal,
    t.total_for_order,
    CASE 
        WHEN t.return_count > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS Return_Status
FROM
    RankedOrders r
LEFT JOIN
    SupplierDetails s ON r.o_orderkey = s.s_suppkey
LEFT JOIN
    TopLineItems t ON r.o_orderkey = t.l_orderkey
WHERE
    (s.s_acctbal IS NULL OR s.s_acctbal > 5000) 
    AND ((r.o_orderstatus = 'O' AND r.o_totalprice < 10000) OR (r.o_orderstatus <> 'O' AND r.o_totalprice >= 10000))
ORDER BY
    r.o_orderkey,
    s.s_acctbal DESC;