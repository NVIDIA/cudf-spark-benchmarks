WITH SalesData AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS total_items,
        DENSE_RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY
        o.o_orderkey
),
TopSales AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        s.total_sales,
        s.total_items
    FROM
        orders o
    JOIN
        SalesData s ON o.o_orderkey = s.o_orderkey
    WHERE
        s.sales_rank <= 10
),
SupplierStats AS (
    SELECT
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS average_supplier_balance
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        ps.ps_suppkey
),
RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        ss.total_supply_cost,
        DENSE_RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS supplier_rank
    FROM
        supplier s
    JOIN
        SupplierStats ss ON s.s_suppkey = ss.ps_suppkey
    WHERE
        ss.average_supplier_balance > 1000
)

SELECT
    ts.o_orderkey,
    ts.o_totalprice,
    ts.total_sales,
    ts.total_items,
    rs.s_name AS top_supplier_name,
    rs.total_supply_cost
FROM
    TopSales ts
LEFT JOIN
    RankedSuppliers rs ON ts.total_sales = rs.total_supply_cost
WHERE
    rs.supplier_rank IS NOT NULL
    OR (rs.supplier_rank IS NULL AND ts.total_items > 5)
ORDER BY
    ts.total_sales DESC, rs.total_supply_cost ASC;