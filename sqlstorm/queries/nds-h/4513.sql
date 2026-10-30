
WITH SupplierSales AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON l.l_partkey = ps.ps_partkey
    WHERE
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY
        s.s_suppkey, s.s_name
),
NationSales AS (
    SELECT
        n.n_name,
        SUM(ss.total_sales) AS nation_sales
    FROM
        nation n
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY
        n.n_name
),
TopNations AS (
    SELECT
        n.n_name,
        ns.nation_sales,
        ROW_NUMBER() OVER (ORDER BY ns.nation_sales DESC) AS rank
    FROM
        nation n
    JOIN
        NationSales ns ON n.n_name = ns.n_name
)
SELECT
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank,
    COALESCE(n.n_name, 'Unknown') AS supplying_nation
FROM
    part p
LEFT JOIN
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN
    nation n ON s.s_nationkey = n.n_nationkey
WHERE
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2
    )
GROUP BY
    p.p_name, n.n_name
HAVING
    SUM(l.l_quantity) > 100
ORDER BY
    sales_rank
LIMIT 10;
