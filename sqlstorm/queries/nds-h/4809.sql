
WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS lineitem_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_custkey
),
HighValueOrders AS (
    SELECT
        od.o_orderkey,
        od.o_custkey,
        od.total_price,
        od.lineitem_count
    FROM
        OrderDetails od
    WHERE
        od.total_price > (
            SELECT
                AVG(total_price) FROM OrderDetails
        )
)
SELECT
    r.r_name AS region,
    n.n_name AS nation,
    s.s_name AS supplier,
    COALESCE(SUM(hvo.total_price), 0) AS total_value,
    AVG(COALESCE(ss.part_count, 0)) AS avg_parts_supplied
FROM
    region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN HighValueOrders hvo ON s.s_suppkey = hvo.o_custkey
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
GROUP BY
    r.r_name, n.n_name, s.s_name
HAVING
    COALESCE(SUM(hvo.total_price), 0) > 0
ORDER BY
    total_value DESC, avg_parts_supplied DESC;
