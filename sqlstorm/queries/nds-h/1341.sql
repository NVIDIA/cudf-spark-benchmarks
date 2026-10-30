WITH RegionalSales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        region r
        JOIN nation n ON r.r_regionkey = n.n_regionkey
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
        JOIN lineitem l ON p.p_partkey = l.l_partkey
        JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY
        r.r_name
),
TopRegions AS (
    SELECT
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        RegionalSales
),
CustomerSegmentSales AS (
    SELECT
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS segment_sales
    FROM
        customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY
        c.c_mktsegment
)
SELECT
    tr.region_name,
    tr.total_sales,
    cs.c_mktsegment,
    cs.segment_sales
FROM
    TopRegions tr
LEFT JOIN CustomerSegmentSales cs ON tr.region_name IS NOT NULL
WHERE
    tr.sales_rank <= 5
ORDER BY
    tr.total_sales DESC, cs.segment_sales DESC;