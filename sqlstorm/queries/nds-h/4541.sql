WITH OrderSummary AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY
        o.o_orderkey, o.o_orderpriority
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
HighVolumeOrders AS (
    SELECT
        os.o_orderkey,
        os.total_revenue,
        sd.s_name,
        ROW_NUMBER() OVER (ORDER BY os.total_revenue DESC) AS rank
    FROM
        OrderSummary os
    LEFT OUTER JOIN
        SupplierDetails sd ON sd.total_supply_cost > 50000  
    WHERE
        os.revenue_rank <= 10
)

SELECT
    hvo.o_orderkey,
    hvo.total_revenue,
    COALESCE(hvo.s_name, 'No Supplier') AS supplier_name
FROM
    HighVolumeOrders hvo
WHERE
    hvo.rank <= 5
ORDER BY
    hvo.total_revenue DESC;