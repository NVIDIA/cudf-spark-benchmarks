WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
        AND o.o_orderdate < DATE '1997-01-01'
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
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1997-01-01'
    GROUP BY 
        l.l_orderkey
),
CustomerRanked AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
),
FilteredSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.total_supply_cost
    FROM 
        SupplierDetails sd
    WHERE 
        sd.total_supply_cost > (
            SELECT AVG(total_supply_cost) FROM SupplierDetails
        )
)
SELECT 
    c.c_name,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    ld.total_revenue,
    fs.s_name AS supplier_name,
    fs.total_supply_cost
FROM 
    RankedOrders o
JOIN 
    LineItemDetails ld ON o.o_orderkey = ld.l_orderkey
LEFT JOIN 
    FilteredSuppliers fs ON fs.total_supply_cost > o.o_totalprice
JOIN 
    CustomerRanked c ON c.customer_rank <= 10
WHERE 
    o.order_rank <= 5 OR o.o_orderstatus = 'F'
ORDER BY 
    o.o_totalprice DESC, c.c_name ASC;