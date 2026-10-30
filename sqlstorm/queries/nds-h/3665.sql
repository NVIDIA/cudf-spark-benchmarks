
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
HighValueOrders AS (
    SELECT 
        os.o_orderkey,
        os.order_total,
        c.c_name,
        c.c_acctbal
    FROM 
        OrderSummary os
    JOIN 
        customer c ON os.o_custkey = c.c_custkey
    WHERE 
        os.order_total > (
            SELECT 
                AVG(order_total) 
            FROM 
                OrderSummary 
            WHERE 
                order_rank <= 10
        )
),
FinalOutput AS (
    SELECT 
        sd.s_name,
        sd.total_parts,
        COALESCE(hvo.order_total, 0) AS high_order_value,
        COALESCE(hvo.c_name, 'N/A') AS customer_name
    FROM 
        SupplierDetails sd
    LEFT JOIN 
        HighValueOrders hvo ON sd.s_suppkey = (
            SELECT 
                ps.ps_suppkey 
            FROM 
                partsupp ps 
            JOIN 
                lineitem l ON ps.ps_partkey = l.l_partkey 
            WHERE 
                l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
            GROUP BY 
                ps.ps_suppkey 
            ORDER BY 
                SUM(l.l_extendedprice * (1 - l.l_discount)) DESC 
            LIMIT 1
        )
)

SELECT 
    f.s_name,
    f.total_parts,
    f.high_order_value,
    f.customer_name
FROM 
    FinalOutput f
WHERE 
    f.high_order_value > 0
ORDER BY 
    f.high_order_value DESC;
