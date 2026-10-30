WITH RegionalSales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY
        r.r_name
),
CustomerSegmentSales AS (
    SELECT
        c.c_mktsegment AS market_segment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS segment_sales
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY
        c.c_mktsegment
),
FinalBenchmark AS (
    SELECT
        rs.region_name,
        COALESCE(cs.market_segment, 'Unknown') AS market_segment,
        rs.total_sales,
        cs.segment_sales
    FROM
        RegionalSales rs
    FULL OUTER JOIN
        CustomerSegmentSales cs ON rs.region_name = cs.market_segment
)
SELECT
    region_name,
    market_segment,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(segment_sales, 0) AS segment_sales
FROM
    FinalBenchmark
ORDER BY
    region_name, market_segment;