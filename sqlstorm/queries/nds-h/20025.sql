WITH RegionalSales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
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
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY
        r.r_regionkey, r.r_name
),
TopRegions AS (
    SELECT
        region_name,
        total_sales,
        customer_count
    FROM
        RegionalSales
    WHERE
        rank_sales <= 3
),
CustomerRank AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT o.o_orderkey) DESC) AS rank_customers
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    tr.region_name,
    tr.total_sales,
    cr.c_name AS top_customer,
    cr.order_count
FROM
    TopRegions tr
LEFT JOIN
    CustomerRank cr ON cr.rank_customers = 1
WHERE
    tr.total_sales > (SELECT AVG(total_sales) FROM TopRegions)
ORDER BY
    tr.total_sales DESC;
