WITH TotalSales AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY
        c.c_custkey, c.c_name
),
SupplierSales AS (
    SELECT
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_amount
    FROM
        partsupp ps
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY
        ps.ps_suppkey
),
AvgSales AS (
    SELECT 
        AVG(total_amount) AS avg_total
    FROM 
        TotalSales
),
CustomerRanked AS (
    SELECT
        ts.c_custkey,
        ts.c_name,
        ts.total_amount,
        RANK() OVER (ORDER BY ts.total_amount DESC) AS rank
    FROM
        TotalSales ts
    WHERE
        ts.total_amount >= (SELECT avg_total FROM AvgSales)
)
SELECT
    cr.c_custkey,
    cr.c_name,
    cr.total_amount,
    COALESCE(ss.supplier_amount, 0) AS supplier_amount,
    CASE 
        WHEN cr.total_amount > 1000 THEN 'High Value'
        WHEN cr.total_amount BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    NULLIF(cr.c_name, '') AS name_check
FROM
    CustomerRanked cr
LEFT JOIN
    SupplierSales ss ON cr.c_custkey = ss.ps_suppkey
WHERE
    cr.rank <= 10
ORDER BY
    cr.total_amount DESC;