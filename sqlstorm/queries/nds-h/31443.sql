WITH  CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
),
SuppSupplierAvg AS (
    SELECT
        ps.ps_partkey,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        ps.ps_partkey
),
HighValueOrders AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY
        o.o_orderkey
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
CustomerRankings AS (
    SELECT
        c.c_custkey,
        c.c_name,
        DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice) DESC) AS cust_rank
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.o_orderdate,
    co.o_totalprice,
    COALESCE(s.avg_acctbal, 0) AS avg_supplier_acctbal,
    CASE 
        WHEN hvo.total_value IS NOT NULL THEN 'High Value' 
        ELSE 'Regular' 
    END AS order_type,
    cr.cust_rank
FROM
    CustomerOrders co
LEFT JOIN
    SuppSupplierAvg s ON co.o_orderkey = s.ps_partkey
LEFT JOIN
    HighValueOrders hvo ON co.o_orderkey = hvo.o_orderkey
JOIN
    CustomerRankings cr ON co.c_custkey = cr.c_custkey
WHERE
    cr.cust_rank <= 10
ORDER BY
    co.o_orderdate DESC, co.c_custkey;