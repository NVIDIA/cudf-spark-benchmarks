WITH ProcessedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        UPPER(p.p_comment) AS upper_comment,
        SUBSTR(p.p_comment, 1, 10) AS truncated_comment
    FROM
        part p
    WHERE
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice)
            FROM part p2
        )
),
SupplierInfo AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        n.n_name AS nation_name
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        n.n_name LIKE 'A%'
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        COUNT(l.l_orderkey) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_custkey
)
SELECT
    pp.p_partkey,
    pp.p_name,
    pp.p_brand,
    pp.upper_comment,
    si.s_name,
    os.item_count,
    os.total_sales
FROM
    ProcessedParts pp
JOIN
    SupplierInfo si ON pp.p_partkey % 10 = si.s_suppkey % 10
JOIN
    OrderSummary os ON pp.p_partkey = os.o_custkey % 100 
WHERE
    pp.truncated_comment <> ''
ORDER BY
    os.total_sales DESC, pp.p_retailprice ASC;