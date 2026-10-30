WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderstatus IN ('O', 'F')
), SupplierDetails AS (
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
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 5000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(sd.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(hvc.c_name, 'Budget Customer') AS customer_name,
    (r.o_totalprice - SUM(COALESCE(l.l_discount, 0)) OVER (PARTITION BY r.o_orderkey)) AS final_price
FROM 
    RankedOrders r
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
LEFT JOIN 
    HighValueCustomers hvc ON r.o_orderkey = hvc.c_custkey
WHERE 
    r.order_rank <= 10
    AND (r.o_totalprice > 1000 OR hvc.customer_rank IS NOT NULL)
ORDER BY 
    r.o_orderdate DESC, r.o_orderkey;