WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_clerk,
        RANK() OVER (PARTITION BY o.o_clerk ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierInfo AS (
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
HighValueItems AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (
            SELECT 
                AVG(p2.p_retailprice)
            FROM 
                part p2
        )
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
)
SELECT 
    o.o_orderkey,
    o.o_totalprice,
    o.o_orderdate,
    o.o_clerk,
    s.total_supply_cost,
    p.p_name,
    p.p_retailprice
FROM 
    RankedOrders o
LEFT JOIN 
    SupplierInfo s ON o.o_orderkey = s.s_suppkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    HighValueItems p ON l.l_partkey = p.p_partkey
WHERE 
    o.o_orderkey IN (
        SELECT o_orderkey
        FROM RankedOrders 
        WHERE order_rank <= 5
    )
    AND (s.total_supply_cost IS NOT NULL OR p.p_retailprice IS NOT NULL)
ORDER BY 
    o.o_orderdate DESC, 
    o.o_totalprice DESC;