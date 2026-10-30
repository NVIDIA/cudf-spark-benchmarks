WITH SupplierSales AS (
    SELECT
        S.s_suppkey,
        S.s_name,
        SUM(L.l_extendedprice * (1 - L.l_discount)) AS total_sales,
        COUNT(DISTINCT O.o_orderkey) AS order_count
    FROM
        supplier S
    JOIN
        partsupp PS ON S.s_suppkey = PS.ps_suppkey
    JOIN
        lineitem L ON PS.ps_partkey = L.l_partkey
    JOIN
        orders O ON L.l_orderkey = O.o_orderkey
    WHERE
        O.o_orderdate >= DATE '1997-01-01' AND O.o_orderdate < DATE '1998-01-01'
    GROUP BY
        S.s_suppkey, S.s_name
),
RegionSales AS (
    SELECT
        N.n_regionkey,
        SUM(S.total_sales) AS region_sales
    FROM
        SupplierSales S
    JOIN
        supplier SUP ON S.s_suppkey = SUP.s_suppkey
    JOIN
        nation N ON SUP.s_nationkey = N.n_nationkey
    GROUP BY
        N.n_regionkey
),
RankedRegions AS (
    SELECT
        R.r_name,
        RS.region_sales,
        RANK() OVER (ORDER BY RS.region_sales DESC) AS sales_rank
    FROM
        region R
    LEFT JOIN
        RegionSales RS ON R.r_regionkey = RS.n_regionkey
)
SELECT
    R.r_name AS region,
    COALESCE(RS.region_sales, 0) AS total_sales,
    RS.sales_rank
FROM
    RankedRegions RS
RIGHT JOIN
    region R ON RS.r_name = R.r_name
WHERE
    (RS.region_sales IS NOT NULL OR R.r_regionkey = 1)
ORDER BY
    sales_rank NULLS LAST, total_sales DESC;