
WITH TotalSales AS (
    SELECT
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        part p
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY
        p.p_partkey
),
SupplierInfo AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_received
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_name
),
PartSuppliers AS (
    SELECT
        t.p_partkey,
        t.total_sales,
        s.s_suppkey,
        s.s_name,
        s.supplier_nation,
        s.total_received
    FROM
        TotalSales t
    JOIN
        SupplierInfo s ON t.p_partkey = s.s_suppkey
)
SELECT
    p.p_partkey,
    p.total_sales,
    ps.s_name AS supplier_name,
    ps.supplier_nation,
    ps.total_received,
    CASE 
        WHEN p.total_sales > ps.total_received THEN 'Sales exceed Supplies'
        ELSE 'Supplies exceed Sales'
    END AS SalesSupplyStatus
FROM
    TotalSales p
LEFT JOIN
    PartSuppliers ps ON p.p_partkey = ps.p_partkey
ORDER BY
    p.total_sales DESC;
