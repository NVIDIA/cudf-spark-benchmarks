
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_value,
        ss.avg_acctbal
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_supply_value > (
            SELECT 
                AVG(total_supply_value) 
            FROM 
                SupplierStats
        )
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    hs.s_name,
    hs.total_supply_value,
    od.o_orderkey,
    od.o_orderdate,
    od.net_order_value,
    ROW_NUMBER() OVER (PARTITION BY hs.s_name ORDER BY od.net_order_value DESC) AS order_rank
FROM 
    HighValueSuppliers hs
LEFT JOIN 
    OrderDetails od ON hs.s_suppkey = (
        SELECT 
            l.l_suppkey 
        FROM 
            lineitem l 
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey 
        WHERE 
            o.o_orderstatus = 'O' 
        AND 
            l.l_tax IS NOT NULL
        ORDER BY 
            l.l_extendedprice DESC 
        LIMIT 1
    )
ORDER BY 
    hs.total_supply_value DESC, 
    od.net_order_value DESC NULLS LAST;
