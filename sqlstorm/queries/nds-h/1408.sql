
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
),
TopSuppliers AS (
    SELECT
        rs.s_suppkey,
        rs.s_name,
        n.n_name AS nation_name,
        rs.s_acctbal
    FROM
        RankedSuppliers rs
    JOIN
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE
        rs.rank <= 3
),
CustomerOrderSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
    GROUP BY
        c.c_custkey, c.c_name
),
PartSales AS (
    SELECT
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        partsupp ps
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY
        ps.ps_suppkey
)
SELECT
    ts.s_name AS supplier_name,
    ts.nation_name,
    cos.c_name AS customer_name,
    cos.order_count,
    cos.total_spent,
    ps.total_sales,
    CASE 
        WHEN ps.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Available'
    END AS sales_status
FROM
    TopSuppliers ts
LEFT JOIN
    CustomerOrderSummary cos ON ts.s_suppkey = (SELECT ps.ps_suppkey
                                                  FROM partsupp ps
                                                  WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'BrandX')
                                                  ORDER BY ps.ps_supplycost ASC LIMIT 1)
LEFT JOIN
    PartSales ps ON ps.ps_suppkey = ts.s_suppkey
ORDER BY
    ts.nation_name, cos.total_spent DESC, ts.s_name;
