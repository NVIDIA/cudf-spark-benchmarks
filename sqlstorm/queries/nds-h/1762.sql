WITH TotalSales AS (
    SELECT
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM
        lineitem
    WHERE
        l_shipdate >= DATE '1997-01-01' AND l_shipdate < DATE '1998-01-01'
    GROUP BY
        l_partkey
),
SupplierSales AS (
    SELECT
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        ps.ps_partkey, s.s_name
),
TopParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        COALESCE(ts.total_sales, 0) AS total_sales,
        COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
        (COALESCE(ts.total_sales, 0) - COALESCE(ss.total_supply_cost, 0)) AS profit
    FROM
        part p
    LEFT JOIN
        TotalSales ts ON p.p_partkey = ts.l_partkey
    LEFT JOIN
        SupplierSales ss ON p.p_partkey = ss.ps_partkey
),
RankedParts AS (
    SELECT
        *,
        RANK() OVER (ORDER BY profit DESC) AS sales_rank
    FROM
        TopParts
)
SELECT
    rp.p_partkey,
    rp.p_name,
    rp.total_sales,
    rp.total_supply_cost,
    rp.profit,
    rp.sales_rank,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM
    RankedParts rp
LEFT JOIN
    lineitem l ON rp.p_partkey = l.l_partkey
LEFT JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    rp.profit > 0
GROUP BY
    rp.p_partkey, rp.p_name, rp.total_sales, rp.total_supply_cost, rp.profit, rp.sales_rank
ORDER BY
    rp.sales_rank
LIMIT 10;