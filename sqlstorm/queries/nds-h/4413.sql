WITH SupplierPerformance AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        supplier s
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        sp.total_returned,
        sp.total_sales
    FROM
        supplier s
    JOIN
        SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
    WHERE
        sp.sales_rank <= 10
),
CustomerOrders AS (
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
        c.c_mktsegment = 'BUILDING'
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    ts.s_name AS supplier_name,
    ts.total_returned,
    ts.total_sales,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    CASE 
        WHEN co.total_spent > 5000 THEN 'High Value' 
        ELSE 'Standard' 
    END AS customer_value_segment
FROM
    TopSuppliers ts
FULL OUTER JOIN
    CustomerOrders co ON ts.s_suppkey = co.c_custkey
WHERE
    (ts.total_sales > 10000 OR co.order_count > 5)
ORDER BY
    ts.total_sales DESC, co.total_spent DESC;
