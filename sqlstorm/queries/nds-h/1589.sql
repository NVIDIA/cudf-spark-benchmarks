
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_shippriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (
            SELECT 
                AVG(total_supply_value)
            FROM (
                SELECT 
                    SUM(ps_supplycost * ps_availqty) AS total_supply_value
                FROM 
                    partsupp ps
                GROUP BY 
                    ps.ps_suppkey
            ) AS SupplierValues
        )
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    sd.s_suppkey,
    sd.s_name,
    sd.region_name
FROM 
    RankedOrders o
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.ps_suppkey
LEFT JOIN 
    SupplierDetails sd ON ts.ps_suppkey = sd.s_suppkey
WHERE 
    o.o_orderstatus = 'O' 
    AND (sd.s_acctbal IS NOT NULL OR sd.s_name LIKE '%Inc%')
    AND EXISTS (
        SELECT 1 
        FROM lineitem l2 
        WHERE l2.l_orderkey = o.o_orderkey AND l2.l_discount > 0.05
    )
ORDER BY 
    o.o_orderdate DESC, o.o_totalprice DESC;
