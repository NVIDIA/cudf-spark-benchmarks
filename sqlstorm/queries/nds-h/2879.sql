WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        COUNT(l.l_orderkey) OVER (PARTITION BY o.o_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    LEFT JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
),
SupplierParts AS (
    SELECT
        ps.ps_partkey,
        s.s_name AS supplier_name,
        SUM(ps.ps_availqty) AS total_available
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        ps.ps_partkey, s.s_name
),
CustomerInfo AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS ranking
    FROM
        customer c
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        c.c_acctbal > 1000
)
SELECT
    o.o_orderkey,
    o.o_orderdate,
    o.lineitem_count,
    o.total_value,
    s.supplier_name,
    (CASE 
        WHEN o.lineitem_count IS NULL THEN 'No Line Items' 
        ELSE 'Has Line Items' 
    END) AS LineItem_Status,
    ci.c_name AS customer_name,
    ci.nation_name
FROM
    RankedOrders o
LEFT JOIN
    SupplierParts s ON o.o_orderkey = s.ps_partkey
JOIN
    CustomerInfo ci ON ci.c_custkey = o.o_orderkey
WHERE
    o.order_rank <= 10
    AND (o.o_orderdate BETWEEN '1997-01-01' AND cast('1998-10-01' as date))
ORDER BY
    o.o_totalprice DESC;