
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank,
        o.o_custkey -- Added to GROUP BY later
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
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
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 50000
),
FilteredLineItems AS (
    SELECT 
        l.*,
        CASE 
            WHEN l.l_discount > 0.05 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE 0
        END AS discounted_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate <= '1997-12-31'
)

SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    rc.c_name AS high_value_customer,
    sd.s_name AS supplier_name,
    SUM(fli.discounted_price) AS total_discounted_value
FROM 
    RankedOrders o
LEFT JOIN 
    HighValueCustomers rc ON o.o_custkey = rc.c_custkey
LEFT JOIN 
    FilteredLineItems fli ON o.o_orderkey = fli.l_orderkey
LEFT JOIN 
    SupplierDetails sd ON fli.l_suppkey = sd.s_suppkey
WHERE 
    o.rank <= 10
GROUP BY 
    o.o_orderkey, o.o_orderdate, o.o_totalprice, rc.c_name, sd.s_name, o.o_custkey
ORDER BY 
    o.o_orderdate DESC;
