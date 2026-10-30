WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM
        orders AS o
    JOIN
        customer AS c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderstatus = 'F'
),
FilteredParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM
        part AS p
    JOIN
        partsupp AS ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name
    HAVING
        SUM(ps.ps_availqty) > 0
),
TopRankedOrders AS (
    SELECT
        * 
    FROM
        RankedOrders 
    WHERE
        rank <= 5
)
SELECT
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    fp.p_name,
    fp.total_cost,
    CASE 
        WHEN r.o_totalprice > fp.total_cost THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM
    TopRankedOrders AS r
LEFT JOIN
    lineitem AS l ON r.o_orderkey = l.l_orderkey
LEFT JOIN
    FilteredParts AS fp ON l.l_partkey = fp.p_partkey
WHERE
    l.l_discount > 0.05
ORDER BY
    r.o_orderdate DESC, r.o_orderkey;
