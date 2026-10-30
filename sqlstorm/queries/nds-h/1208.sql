WITH SupplierSummary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderstatus = 'O' AND
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY
        o.o_orderkey, o.o_custkey
),
NationAvg AS (
    SELECT
        n.n_nationkey,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM
        nation n
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        n.n_nationkey
)
SELECT
    r.r_name,
    SUM(os.total_price) AS total_order_value,
    AVG(sa.total_supply_cost) AS avg_supply_cost,
    na.avg_acctbal
FROM
    region r
LEFT JOIN
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN
    OrderSummary os ON n.n_nationkey = os.o_custkey
LEFT JOIN
    SupplierSummary sa ON sa.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type LIKE '%COMPONENT%'))
LEFT JOIN
    NationAvg na ON n.n_nationkey = na.n_nationkey
GROUP BY
    r.r_name, na.avg_acctbal
HAVING
    SUM(os.total_price) > (SELECT AVG(total_price) FROM OrderSummary)
ORDER BY
    r.r_name;